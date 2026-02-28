openssl req -new -x509 -newkey rsa:2048 -keyout mok.key -outform DER -out mok.pub -days 36500 -subj "/CN=Your Name/" -nodes
openssl x509 -inform DER -in mok.pub -out mok.pem
