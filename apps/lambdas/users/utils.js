export function convertHeaderListToJson(headerList) {
    const result = {};
    for (const headerIdx in headerList) {
        result[headerIdx] = headerList[headerIdx];
    }
    return result;
}

export function convertRowToObject(headersMap, row) {
    const result = {};
    for (const propIdx in row) {
        result[headersMap[propIdx]] = row[propIdx];
    }
    return result;
}

export function getSqlByRequestParams(reqParam, tableName) {
    if (reqParam === undefined) {
        return `SELECT * FROM "${tableName}"`
    }
    else {
        return `SELECT * FROM "${tableName}" WHERE id = "${reqParam}"`
    }
}
