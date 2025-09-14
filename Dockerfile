# Start with a base Python image.
# Using a "slim" image is good practice for smaller images.
FROM python:3.13-slim

# Set the working directory in the container
WORKDIR /app

# (Optional) You can remove this step now
# The psycopg2-binary package doesn't require these dependencies.
# This makes your image smaller and your build faster.
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     libpq-dev \
#     gcc \
#     && apt-get clean \
#     && rm -rf /var/lib/apt/lists/*

# Install pipenv
RUN pip install pipenv

# Copy Pipfile and Pipfile.lock to the working directory
COPY Pipfile Pipfile.lock ./

# Install project dependencies from Pipfile.lock
# This ensures a deterministic and repeatable build.
RUN pipenv install --deploy --system

# Copy the rest of the application code into the container
COPY . .

# Expose the port the application runs on
EXPOSE 8000

# Command to run the application
# Replace `python your_app_name.py` with your actual startup command.
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]