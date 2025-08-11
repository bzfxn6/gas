exports.handler = async (event) => {
    console.log('Lambda Three executed');
    return {
        statusCode: 200,
        body: JSON.stringify({
            message: 'Lambda Three completed',
            input: event
        })
    };
}; 