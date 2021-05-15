function buildDefaultResponse() {
    return {
        status: '404',
        statusDescription: 'Not Found',
        headers: {
            'cache-control': [{
                key: 'Cache-Control',
                value: 'no-cache'
            }],
            'content-type': [{
                key: 'Content-Type',
                value: 'text/plain'
            }]
        },
        body: 'Not Found',
    };
}

function isHostMatching(a, b) {
    return !a ? false : (('string' === typeof a) ? (a === b) : !!b.match(a));
}
function isUriMatching(a, b) {
    return !a ? false : (('string' === typeof a) ? (a === b) : !!b.match(a));
}
function applyTest(a, b) {
    return !a ? false : (('function' === typeof a) ? !!a(b) : false);
}
function isCountryMatching(a, b) {
    return !a ? false : (Array.isArray(a) ? a.includes(b) : (a === b));
}

function matchRuleAndOptionallyUpdateRule(rule, context) {
    let r = undefined;
    // noinspection PointlessBooleanExpressionJS
    rule.host && (r = ((undefined !== r) ? r : true) && isHostMatching(rule.host, context.host));
    rule.uri && (r = ((undefined !== r) ? r : true) && isUriMatching(rule.uri, context.uri));
    rule.country && (r = ((undefined !== r) ? r : true) && isCountryMatching(rule.country, context.country));
    if (rule.test) {
        r = ((undefined !== r) ? r : true);
        const testResult = applyTest(rule.test, context);
        if (!!testResult && ('string' === typeof testResult)) {
            rule.location = testResult;
        }
        r = r && !!testResult;
    }
    return r;
}

function getHeaderFromRequest(request, name, defaultValue = undefined) {
    const headers = getHeadersFromRequest(request);
    const value = ((headers[name] || headers[(name || '').toLowerCase()] || [])[0] || {}).value;
    return (undefined === value) ? defaultValue : value;
}

function getHeadersFromRequest(request) {
    return request.headers || [];
}

function getUriFromRequest(request, {refererMode = false} = {}) {
    if (!refererMode) return request.uri;
    let host = getHeaderFromRequest(request, 'Host');
    let referer = getHeaderFromRequest(request, 'Referer');
    if (host && referer) return referer.split(host)[1];
    return request.uri;
}

async function getRedirectResponseIfExistFromConfig(request, config) {
    const context = {
        host: getHeaderFromRequest(request, 'Host'),
        uri: getUriFromRequest(request, config),
        country: getHeaderFromRequest(request, 'CloudFront-Viewer-Country'),
        headers: getHeadersFromRequest(request),
    };
    return ((config || {}).redirects || []).find(
        rule => matchRuleAndOptionallyUpdateRule(rule, context, request)
    );
}

async function getRedirectResponseIfExistForRequest(request, config) {
    const rule = await getRedirectResponseIfExistFromConfig(request, config);
    return !rule ? undefined : {
        status: rule.status || '302',
        statusDescription: 'Found',
        headers: {
            ...(rule.headers || {}),
            location: [{
                key: 'Location',
                value: rule.location,
            }],
        },
    };
}
function selectRegionalItem(items, region) {
    const tries = {
        'eu-west-3': ['eu-west-3', 'eu-west-2', 'eu-central-1', 'eu-west-1', 'us-east-1', 'us-west-1'],
        'eu-west-2': ['eu-west-2', 'eu-west-3', 'eu-central-1', 'eu-west-1', 'us-east-1', 'us-west-1'],
        'eu-west-1': ['eu-west-1', 'eu-west-2', 'eu-west-3', 'eu-central-1', 'us-east-1', 'us-west-1'],
        'eu-central-1': ['eu-central-1', 'eu-west-3', 'eu-west-2', 'eu-west-1', 'us-east-1', 'us-west-1'],
        'us-east-1': ['us-east-1', 'us-west-1', 'eu-west-1', 'eu-west-2', 'eu-west-3', 'eu-central-1'],
        'us-west-1': ['us-west-1', 'us-east-1', 'eu-west-1', 'eu-west-2', 'eu-west-3', 'eu-central-1'],
        'eu': ['eu-west-1', 'eu-west-2', 'eu-west-3', 'eu-central-1', 'us-east-1', 'us-west-1'],
        'us': ['us-east-1', 'us-west-1', 'eu-west-1', 'eu-west-2', 'eu-west-3', 'eu-central-1'],
        '*': ['eu-west-3', 'eu-west-2', 'eu-west-1', 'eu-central-1', 'us-east-1', 'us-west-1'],
    }
    const z = tries[region] || tries[region.split('-')[0]] || tries['*'];
    return items[z.find(i => !!items[i]) || region];
}

async function getRegionalS3OriginRequestIfNeededForRequest(request, config) {
    if (!request || !request.origin || !request.origin.s3) return undefined;
    const buckets = getJsonEncodedCustomHeaderValue(request.origin.s3, 'x-razzle-buckets');
    const bucket = selectRegionalItem(buckets, request.origin.s3.region);
    console.log(JSON.stringify({buckets, bucket}));
    request.origin = {
        s3: {
            domainName: bucket.domain,
            region: request.origin.s3.region,
            authMethod: request.origin.s3.authMethod,
            path: request.origin.s3.path,
            customHeaders: {}
        }
    }
    request.headers['host'] = [{ key: 'Host', value: bucket.domain}]
    return request;
}
function getJsonEncodedCustomHeaderValue(origin, key) {
    return JSON.parse(((origin.customHeaders[key.toLowerCase()] || [])[0] || {}).value || '{}');
}
async function getRegionalApiGatewayOriginRequestIfNeededForRequest(request, config) {
    if (!request || !request.origin || !request.origin.custom) return undefined;
    const apps = getJsonEncodedCustomHeaderValue(request.origin.custom, 'x-razzle-apps');
    // @todo do a better selection
    const app = Object.values(apps)[0];
    console.log(JSON.stringify({apps, app}));
    request.origin = {
        custom: {
            domainName: app.domain,
            port: request.origin.custom.port,
            protocol: request.origin.custom.protocol,
            path: request.origin.custom.path,
            sslProtocols: request.origin.custom.sslProtocols,
            readTimeout: request.origin.custom.readTimeout,
            keepaliveTimeout: request.origin.custom.keepaliveTimeout,
            customHeaders: {},
        }
    }
    request.headers['host'] = [{ key: 'Host', value: app.domain}]
    return request;
}

async function processRequest(request) {
    let config = require('./config');
    if ('function' === typeof config) config = config(request);
    let result = await getRedirectResponseIfExistForRequest(request, config);
    result = result || await getRegionalS3OriginRequestIfNeededForRequest(request, config);
    result = result || await getRegionalApiGatewayOriginRequestIfNeededForRequest(request, config);
    console.log({result: JSON.stringify(result), request: JSON.stringify(request)});
    return result || request;
}

module.exports = {
    buildDefaultResponse,
    processRequest,
}