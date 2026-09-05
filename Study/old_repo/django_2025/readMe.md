## create

django-admin startproject project1 .
python3 manage.py startapp app1


## add in setting installed app
rest_framework
app1
rest_framework.authtoken

## migrate

python3 manage.py makemigrations
python3 manage.py migrate
python3 manage.py createsuperuser


## create token
python3 manage.py drf_create_token