import AWS from '@aws-sdk/client-athena';
import { Repository } from './Repository.js';
import { getSqlByRequestParams } from './utils.js';

// Create an Athena client
const athena = new AWS.Athena();
const repo = new Repository(athena);

export const handler = async (event, context) => {
    const DB_NAME = process.env.DATABASE_NAME;
    const TABLE_NAME = process.env.TABLE_NAME;
    const WORKGROUP = process.env.ATHENA_WORKGROUP;
    const OUTPUT_LOCATION = `s3://${process.env.ATHENA_OUTPUT_PATH}/`;

    const idStartIndex = event.path.lastIndexOf('users/');
    const reqParam = idStartIndex !== -1 ? event.path.substring(idStartIndex + 6) : undefined;

    // Set the Athena query string
    const query = getSqlByRequestParams(reqParam, TABLE_NAME); // Replace with your actual database and table

    // Set the query execution context
    const queryParams = {
        QueryString: query,
        QueryExecutionContext: {
            Database: DB_NAME,
        },
        ResultConfiguration: {
            OutputLocation: OUTPUT_LOCATION,
        },
        WorkGroup: WORKGROUP,
    };

    try {
        const result = await repo.execute(queryParams);
        return {
            statusCode: 200,
            body: JSON.stringify({ users: result }),
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
