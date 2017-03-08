package main

import (
				"log"
				"time"
				"net"
				"regexp"
				"sync"
				"os"
				"jlaffaye/ftp"
)
// Debido a malos funcionamientos de algunos FTPs, he modificado la libreria de jlaffaye para que meta Timeouts cada 3sg y no se queden conexiones establecidas.

///////// Tocar desde aqui ////////

const rutines = 130

var rangos = []string{"X.X.X.X/X", "Y.Y.Y.Y/Y"}

//////// Hasta aqui ///////

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
								ftpCL, err := ftp.DialTimeout(in+":21", time.Second)
								if err != nil{
												wg.Done()
												continue
								}
								temp := [2]string{in, ""}
								err = ftpCL.Login("anonymous", "anonymous")
								if err != nil{
												temp[1] = err.Error()
								}else{
												temp[1] = "Anonymous login allowed"
								}
								ftpCL.Quit()
								res <- temp
								log.Println(temp)
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
								f, err := os.Create("netcrawler_ftp_" + rango[0:len(rango)-3] + ".txt")
								check(err)
								for len(results)>0{
												a_res = <-results
												f.WriteString(a_res[0] + " - " + a_res[1] + "\n")
								}
								f.Close()
								log.Println("Range", rango, "done!")
				}
}
