#!/bin/bash

# Package Lambda One
cd lambda_one
zip -r ../lambda_one.zip .
cd ..

# Package Lambda Two
cd lambda_two
zip -r ../lambda_two.zip .
cd ..

# Package Lambda Three
cd lambda_three
zip -r ../lambda_three.zip .
cd ..

echo "Lambda functions packaged successfully!" 