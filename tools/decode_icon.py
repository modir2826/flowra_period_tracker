import base64
b = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAAWgmWQ0AAAAASUVORK5CYII='
open('assets/icon.png','wb').write(base64.b64decode(b))
print('Wrote assets/icon.png')
