# Stage 1: Build the application dependencies
# Use a more recent and supported Python base image
FROM python:3.12-slim AS build

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install the PostgreSQL client development libraries
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
# Use the same base image as the build stage for consistency and ease of maintenance
FROM python:3.12-slim

# Set the working directory
WORKDIR /app

# Copy the dependencies from the build stage
COPY --from=build /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=build /usr/local/bin/gunicorn /usr/local/bin/gunicorn

# Copy the application code
COPY . /app/

# Expose the port
EXPOSE 8000

# Collect static files (if your Django project uses them)
RUN python3 manage.py collectstatic --noinput

# Start the application with a production-ready server like Gunicorn
CMD ["gunicorn", "pythonbangla_project.wsgi", "--bind", "0.0.0.0:8000", "--log-file", "-"]