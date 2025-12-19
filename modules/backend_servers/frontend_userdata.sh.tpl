#!/bin/bash
yum update -y
yum install httpd -y
systemctl start httpd
systemctl enable httpd

# Creamos un index.html que carga la imagen desde el S3
cat <<EOF > /var/www/html/index.html
<html>
<head>
    <title>Servidor Web (Emulador CDN)</title>
    <meta charset="UTF-8">
    <style>
        body { font-family: sans-serif; text-align: center; padding-top: 50px; background-color: #f0f0f0; }
        h1 { color: #d9534f; }
        p { font-size: 1.1rem; }
        img { max-width: 300px; border: 2px solid #ccc; border-radius: 8px; margin-top: 20px; }
    </style>
</head>
<body>
    <h1>Servidor Web (Emulador CDN)</h1>
    <p>Esta p&aacute;gina est&aacute; servida desde una instancia <strong>EC2</strong>.</p>
    <p>La imagen de abajo est&aacute; alojada en <strong>S3</strong> (mi-proyecto-static-site):</p>

    <img src="http://${s3_website_url}/${s3_image_name}" alt="Logo desde S3">
</body>
</html>
EOF