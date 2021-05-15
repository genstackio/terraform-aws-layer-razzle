const {buildDefaultResponse, processRequest} = require('./utils');

const handler = async event => {
    console.log({event: JSON.stringify(event, null, 4)});
    const records = ((event || {})['Records'] || []);
    if (!records.length) return buildDefaultResponse();
    const request = ((records[0] || {})['cf'] || {})['request'];
    if (!request) return buildDefaultResponse();

    return processRequest(request);
};

module.exports = {handler}