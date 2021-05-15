const {buildDefaultResponse, enrichResponse} = require('./utils');

const handler = async event => {
    console.log({event: JSON.stringify(event, null, 4)});
    const records = ((event || {})['Records'] || []);
    if (!records.length) return buildDefaultResponse();
    const response = ((records[0] || {})['cf'] || {})['response'];
    if (!response) return buildDefaultResponse();

    return enrichResponse(response);
};

module.exports = {handler}