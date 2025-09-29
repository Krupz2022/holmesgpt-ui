To run

step 1

Git clone

step 2 
place web folder content in /var/www/html [Assuming using Apache2 or Nginx]

step 3 Initialize Go 
cd holmesgpt-ui
go mod init holmesgpt-ui
go mod tidy

step 4
Run the server
cd api/cmd/server
go run .
