# Stage 1: Build the application dependencies
# Use a Python base image with a specific version
FROM python:3.10-slim-buster AS build

# Set environment variables for the build process
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install pipenv and dependencies
RUN pip install pipenv

# Set the working directory
WORKDIR /app

# Copy Pipfile and Pipfile.lock to the container
COPY Pipfile Pipfile.lock /app/

# Install project dependencies into a virtual environment
# The --system flag installs packages directly to the system site-packages
# This is a good practice for Docker containers to avoid issues with virtualenvs
RUN pipenv install --system --deploy --ignore-pipfile

# Stage 2: Create the final, smaller runtime image
FROM python:3.10-slim-buster

# Set the working directory
WORKDIR /app

# Copy the dependencies from the build stage
# This copies the installed packages from the virtual environment
COPY --from=build /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=build /usr/local/bin/gunicorn /usr/local/bin/gunicorn

# Copy the entire project code into the container
COPY . /app/

# Expose the port on which the application will run
EXPOSE 8000

# Collect static files
# This is crucial for production. You might want to handle this differently
# if you are using a CDN like S3. For a simple container deployment, this is fine.
RUN python3 manage.py collectstatic --noinput

# Define the command to run the application using Gunicorn
# This is based on the "Setup And Running in Heroku" section of your README
CMD ["gunicorn", "pythonbangla_project.wsgi", "--bind", "0.0.0.0:8000", "--log-file", "-"]