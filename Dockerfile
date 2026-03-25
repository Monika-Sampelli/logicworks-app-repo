# Use a lightweight web server to host a success page
FROM nginx:alpine

# Create a custom HTML file to verify the deployment
RUN echo "<h1>Logicworks DevOps Project: Multi-Region Deployment Successful</h1>" > /usr/share/nginx/html/index.html

# Expose port 80 for the ECS Service
EXPOSE 80
