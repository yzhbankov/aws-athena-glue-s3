import AWS from '@aws-sdk/client-athena';

// Create an Athena client
const athena = new AWS.Athena();

export const handler = async (event, context) => {
    const DB_NAME = process.env.DATABASE_NAME;
    const TABLE_NAME = process.env.TABLE_NAME;
    const WORKGROUP = process.env.ATHENA_WORKGROUP;
    const OUTPUT_LOCATION = `s3://${process.env.ATHENA_OUTPUT_PATH}/`;

    // Set the Athena query string
    const query = `SELECT * FROM "${TABLE_NAME}" where email like 'ihor%'`; // Replace with your actual database and table

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
        // Execute the Athena query
        const queryExecution = await athena.startQueryExecution(queryParams);

        // Get the query execution ID
        const queryExecutionId = queryExecution.QueryExecutionId;

        // Wait for the query to complete
        await waitForQuery(queryExecutionId);

        // Get the query results
        const queryResults = await getQueryResults(queryExecutionId);

        // Return a successful response
        return {
            statusCode: 200,
            body: JSON.stringify({ users: queryResults }),
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


// Helper function to wait for Athena query completion
async function waitForQuery(queryExecutionId) {
    const params = {
        QueryExecutionId: queryExecutionId,
    };

    while (true) {
        const response = await athena.getQueryExecution(params);
        const status = response.QueryExecution.Status.State;

        if (status === 'SUCCEEDED' || status === 'FAILED' || status === 'CANCELLED') {
            break;
        }

        // Wait for a few seconds before checking again
        await new Promise((resolve) => setTimeout(resolve, 5000));
    }
}

// Helper function to get Athena query results
async function getQueryResults(queryExecutionId) {
    const params = {
        QueryExecutionId: queryExecutionId,
    };

    const response = await athena.getQueryResults(params);
    const rows = response.ResultSet.Rows.map(row => row.Data.map((data) => data.VarCharValue));
    const headerMap = convertHeaderListToJson(rows[0]);
    return rows.reduce((memo, row, idx) => {
        if (idx !== 0) {
            memo.push(convertRowToObject(headerMap, row));
        }
        return memo;
    }, []);
}

function convertHeaderListToJson(headerList) {
    const result = {};
    for (const headerIdx in headerList) {
        result[headerIdx] = headerList[headerIdx];
    }
    return result;
}

function convertRowToObject(headersMap, row) {
    const result = {};
    for (const propIdx in row) {
        result[headersMap[propIdx]] = row[propIdx];
    }
    return result;
}
