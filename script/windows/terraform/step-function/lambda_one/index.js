exports.handler = async (event) => {
    console.log('Lambda One executed');
    return {
        statusCode: 200,
        body: JSON.stringify({
            message: 'Lambda One completed',
            input: event
        })
    };
}; 