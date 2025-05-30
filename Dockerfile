FROM python:3.10

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install dependencies with updated pip
COPY requirements.txt /app/
RUN pip install --upgrade pip && \
    pip install -r /app/requirements.txt

# Create and set working directory
RUN mkdir -p /app
WORKDIR /app/blog_project

# Copy entire project
COPY . /app/

# Copy our custom settings file
COPY config/settings.py /app/blog_project/blog_project/settings.py

# Run the application
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "blog_project.wsgi:application"]
