const AWS = require('aws-sdk');

const ddb = new AWS.DynamoDB.DocumentClient({ apiVersion: '2012-08-10', region: '<REGION>' });

exports.handler = async event => {
  const deleteParams = {
    TableName: '<TABLENAME>',
    Key: {
      <ID>: event.requestContext.<ID>
    }
  };

  try {
    await ddb.delete(deleteParams).promise();
  } catch (err) {
    console.log('Failed to disconnect: ' + JSON.stringify(err));
    return { statusCode: 500, body: 'Failed to disconnect' };
  }

  return { statusCode: 200, body: 'Disconnected.' };
};
