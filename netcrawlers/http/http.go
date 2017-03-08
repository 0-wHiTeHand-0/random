package main

import (
				"io/ioutil"
				"log"
				"time"
				"net"
				"net/http"
				"regexp"
				"sync"
				"strings"
				"os"
)

// Recorre los rangos haciendo peticiones al puerto 80, y matcheando la respuesta con la funcion "procesa". Timeout de 1sg a nivel de tcp, y de 6sg a nivel de http.

//////// Tocar desde aqui /////////

const rutines = 130
var rangos = []string{"X.X.X.X/X", "Y.Y.Y.Y/Y"}

func procesa(st string) (string){
				if strings.Contains(strings.ToLower(st), "EXPECTEDTEXTINRESPONSE"){
								return "PRODUCTNAME"
				}else if (strings.Contains(strings.ToLower(st), "ANOTHEREXPECTEDTEXTINRESPONSE")){
								return "ANOTHERPRODUCTNAME"
				}//etc

				return ""
}

/////// Hasta aqui ///////

func check(err2 error){
				if err2 != nil {
								log.Fatal(err2)
				}
}

func inc(ip net.IP) {
				for j := len(ip)-1; j>=0; j-- {
								ip[j]++
								if ip[j] > 0 {
												break
								}
				}
}

func Hosts(cidr string) ([]string) {
				re := regexp.MustCompile(`\.(0|255)$`)
				ip, ipnet, err := net.ParseCIDR(cidr)
				check(err)
				res := []string{}
				for ip := ip.Mask(ipnet.Mask); ipnet.Contains(ip); inc(ip) {
								ma := re.MatchString(ip.String())
								if !ma{
										res = append(res, ip.String())
								}
				}
				return res
}

func f_req(jobs <-chan string, res chan<- [2]string, wg *sync.WaitGroup) {
				for in := range jobs{
								transport := http.Transport{
												Dial: (&net.Dialer{
																Timeout: time.Second,
												}).Dial,
												DisableKeepAlives: true,
								}
								client := http.Client{
												Transport: &transport,
												Timeout: time.Duration(6*time.Second),
								}
								//log.Println("IP:", in)
								req, err := http.NewRequest("GET", "http://" + in, nil)
								check(err)
								req.Header.Set("User-Agent", "Mozilla/5.0 (X11; Linux x86_64; rv:50.0) Gecko/20100101 Firefox/50.0")
								resp, err := client.Do(req)
								if err != nil{
												wg.Done()
												continue
								}
								body, err := ioutil.ReadAll(resp.Body)
								resp.Body.Close()
								if err != nil{
												wg.Done()
												continue
								}
								tmp := [2]string{in, procesa(string(body))}
								if tmp[1] != ""{
												res <- tmp
												log.Println(tmp)
								}
								wg.Done()
				}
}

func main() {
				jobs := make(chan string)
				results := make(chan [2]string, 524500)
				var a_res [2]string
				var wg sync.WaitGroup
				for w := 1; w <= rutines; w++ {
								go f_req(jobs, results, &wg)
				}
				for _, rango := range rangos{
								for _, ip := range Hosts(rango){
												wg.Add(1)
												jobs <- ip
								}
								wg.Wait()
								f, err := os.Create("netcrawler_results_" + rango[0:len(rango)-3] + ".txt")
								check(err)
								for len(results)>0{
												a_res = <-results
												f.WriteString(a_res[0] + " - " + a_res[1] + "\n")
								}
								f.Close()
								log.Println("Range", rango, "done!")
				}
}
