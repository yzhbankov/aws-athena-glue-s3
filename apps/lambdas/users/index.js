const AWS = require('aws-sdk');

exports.handler = async (event, context) => {
    const DB_NAME = process.env.DATABSE_NAME;
    const TABLE_NAME = process.env.TABLE_NAME;
    const AWS_REGION = process.env.ATHENA_REGION;
    // Set the AWS region
    AWS.config.update({ region: AWS_REGION }); // Replace with your desired region

    // Create an Athena client
    const athena = new AWS.Athena();

    // Set the Athena query string
    const query = `SELECT * FROM "${DB_NAME}"."${TABLE_NAME}"`; // Replace with your actual database and table

    // Set the Athena workgroup (optional, if not using the default workgroup)
    const workgroup = process.env.ATHENA_WORKGROUP; // Replace with your actual workgroup

    // Set the output location for query results (S3 bucket)
    const outputLocation = process.env.ATHENA_OUTPUT_PATH; // Replace with your actual S3 bucket

    // Set the query execution context
    const queryParams = {
        QueryString: query,
        ResultConfiguration: {
            OutputLocation: outputLocation,
        },
        WorkGroup: workgroup,
    };

    try {
        // Execute the Athena query
        const result = await athena.startQueryExecution(queryParams).promise();

        // Log the query execution ID
        console.log(`Query Execution ID: ${result.QueryExecutionId}`);

        // Return a successful response
        return {
            statusCode: 200,
            body: JSON.stringify({ message: 'Athena query execution started successfully' }),
        };
    } catch (error) {
        // Log and return an error response
        console.error('Error executing Athena query:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Error executing Athena query', error: error.message }),
        };
    }
};
