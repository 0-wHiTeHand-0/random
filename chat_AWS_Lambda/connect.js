const AWS = require('aws-sdk');

const ddb = new AWS.DynamoDB.DocumentClient({ apiVersion: '2012-08-10', region: '<REGION>' });

exports.handler = async event => {
  const putParams = {
    TableName: '<TABLENAME>',
    Item: {
      <ID>: event.requestContext.<ID>
    }
  };
  
  if (event.headers['Origin'] != '<YOURORIGIN>'){
    console.log('Bad Origin from: ' + event.requestContext.identity.sourceIp);
    return { statusCode: 400, body: 'Bad Origin.' };
  }

  try {
    await ddb.put(putParams).promise();
  } catch (err) {
    console.log('Failed to connect: ' + JSON.stringify(err));
    return { statusCode: 500, body: '{"username":"Error","message":"Error"}' };
  }

  console.log('Connected successfully: ' + event.requestContext.identity.sourceIp);
  return { statusCode: 200, body: 'Connected.' };
};
