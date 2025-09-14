# Stage 1: Build the application dependencies
# Use a Python base image with a specific version
FROM python:3.10-slim-buster AS build

# Set environment variables for the build process
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install pipenv and the PostgreSQL client development libraries
# This is the crucial fix for the "pg_config not found" error
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       postgresql-client \
       libpq-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install pipenv
RUN pip install pipenv

# Set the working directory
WORKDIR /app

# Copy Pipfile and Pipfile.lock to the container
COPY Pipfile Pipfile.lock /app/

# Install project dependencies into a virtual environment
RUN pipenv install --system --deploy --ignore-pipfile

# Stage 2: Create the final, smaller runtime image
FROM python:3.10-slim-buster

# Set the working directory
WORKDIR /app

# Copy the dependencies from the build stage
COPY --from=build /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=build /usr/local/bin/gunicorn /usr/local/bin/gunicorn

# Copy the entire project code into the container
COPY . /app/

# Expose the port on which the application will run
EXPOSE 8000

# Collect static files
RUN python3 manage.py collectstatic --noinput

# Define the command to run the application using Gunicorn
CMD ["gunicorn", "pythonbangla_project.wsgi", "--bind", "0.0.0.0:8000", "--log-file", "-"]