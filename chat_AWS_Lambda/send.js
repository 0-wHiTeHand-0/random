"use strict";
const AWS = require('aws-sdk');
const ddb = new AWS.DynamoDB.DocumentClient({ apiVersion: '2012-08-10', region: 'eu-west-3' });

exports.handler = async event => {
  console.log('New message from ' + event.requestContext.identity.sourceIp + ': ' + event.body);
  
  let postData;
  try {
    postData = JSON.parse(event.body).data;
    if ((postData.username.length > 40) || (postData.message.length > 2000)){
      console.log('Too long message');
      return { statusCode: 400, body: '{"username":"Error","message":"Demasiado largo. Abrevia."}' };
    }else{
      postData = JSON.stringify(postData);
    }
  } catch (e) {
    console.log(e);
    return { statusCode: 400, body: '{"username":"Error","message":"Input error"}' };
  }
  
  let connectionData;
  try {
    connectionData = await ddb.scan({ TableName: 'chat-connections', ProjectionExpression: 'connectionId' }).promise();
  } catch (e) {
    console.log(e);
    return { statusCode: 500, body: '{"username":"Error","message":"Error"}' };
  }
  
  const apigwManagementApi = new AWS.ApiGatewayManagementApi({
    apiVersion: '2018-11-29',
    endpoint: event.requestContext.domainName + '/' + event.requestContext.stage
  });

  const postCalls = connectionData.Items.map(async ({ connectionId }) => {
    if (connectionId != event.requestContext.connectionId){
      try {
        await apigwManagementApi.postToConnection({ ConnectionId: connectionId, Data: postData }).promise();
      } catch (e) {
        if (e.statusCode === 410) {
          console.log(`Found stale connection, deleting ${connectionId}`);
          await ddb.delete({ TableName: 'chat-connections', Key: { connectionId } }).promise();
        } else {
          throw e;
        }
      }
    }
  });
  
  try {
    await Promise.all(postCalls);
  } catch (e) {
    console.log(e);
    return { statusCode: 500, body: '{"username":"Error","message":"Error"}' };
  }

 return { statusCode: 200, body: postData };
};
