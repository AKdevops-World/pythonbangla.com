# Stage 1: Build the application dependencies
# Use a Python base image with a specific version
FROM python:3.10-slim-buster AS build

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install pipenv and the PostgreSQL client development libraries
# This step is crucial for building psycopg2 from source
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    gcc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install pipenv
RUN pip install pipenv

# Set the working directory
WORKDIR /app

# Copy Pipfile and Pipfile.lock
COPY Pipfile Pipfile.lock /app/

# Install project dependencies
RUN pipenv install --system --deploy --ignore-pipfile

# Stage 2: Create the final, smaller runtime image
FROM python:3.10-slim-buster

# Set the working directory
WORKDIR /app

# Copy the dependencies from the build stage
COPY --from=build /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages

# Copy the application code
COPY . /app/

# Expose the port
EXPOSE 8000

# Collect static files (if your Django project uses them)
RUN python3 manage.py collectstatic --noinput

# Start the application with a production-ready server like Gunicorn
CMD ["gunicorn", "pythonbangla_project.wsgi", "--bind", "0.0.0.0:8000", "--log-file", "-"]