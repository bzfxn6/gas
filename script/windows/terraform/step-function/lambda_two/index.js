exports.handler = async (event) => {
    console.log('Lambda Two executed');
    return {
        statusCode: 200,
        body: JSON.stringify({
            message: 'Lambda Two completed',
            input: event
        })
    };
}; 