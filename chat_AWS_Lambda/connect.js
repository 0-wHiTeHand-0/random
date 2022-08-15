"use strict";
const AWS = require('aws-sdk');

const ddb = new AWS.DynamoDB.DocumentClient({ apiVersion: '2012-08-10', region: 'eu-west-3' });

exports.handler = async event => {
  if (event.headers['Origin'] != '<YOURORIGIN>'){
    console.log('Bad Origin from: ' + event.requestContext.identity.sourceIp);
    return { statusCode: 400, body: 'Bad Origin.' };
  }

  const putParams = {
    TableName: 'chat-connections',
    Item: {
      connectionId: event.requestContext.connectionId,
      timetolive: Math.round((Date.now()/1000)+(8*3600))
      //timetolive: Math.round(Date.now()/1000)+(15)
    }
  };

  try {
    await ddb.put(putParams).promise();
  } catch (err) {
    console.log('Failed to connect: ' + JSON.stringify(err));
    return { statusCode: 500, body: '{"username":"Error","message":"Error"}' };
  }

  console.log('Connected successfully: ' + event.requestContext.identity.sourceIp);
  return { statusCode: 200, body: 'Connected.' };
};
