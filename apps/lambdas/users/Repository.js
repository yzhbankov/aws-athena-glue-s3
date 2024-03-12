import { convertHeaderListToJson, convertRowToObject } from './utils.js';

export class Repository {
    constructor(athena) {
        this.athena = athena;
    }

    async #waitForQuery(queryExecutionId) {
        const params = {
            QueryExecutionId: queryExecutionId,
        };

        while (true) {
            const response = await this.athena.getQueryExecution(params);
            const status = response.QueryExecution.Status.State;

            if (status === 'SUCCEEDED' || status === 'FAILED' || status === 'CANCELLED') {
                break;
            }

            // Wait for a few seconds before checking again
            await new Promise((resolve) => setTimeout(resolve, 5000));
        }
    }

    async #getQueryResults(queryExecutionId) {
        const params = {
            QueryExecutionId: queryExecutionId,
        };

        const response = await this.athena.getQueryResults(params);
        const rows = response.ResultSet.Rows.map(row => row.Data.map((data) => data.VarCharValue));
        const headerMap = convertHeaderListToJson(rows[0]);
        return rows.reduce((memo, row, idx) => {
            if (idx !== 0) {
                memo.push(convertRowToObject(headerMap, row));
            }
            return memo;
        }, []);
    }

    async execute(queryParams) {
        // Execute the Athena query
        const queryExecution = await this.athena.startQueryExecution(queryParams);

        // Get the query execution ID
        const queryExecutionId = queryExecution.QueryExecutionId;

        // Wait for the query to complete
        await this.#waitForQuery(queryExecutionId);

        // Get the query results
        return this.#getQueryResults(queryExecutionId);
    }
}
