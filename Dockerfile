# ------------------------ BUILD ----------------------- #

FROM python:3.9-slim-buster AS builder

# Install build requirements
RUN apt-get update && apt-get upgrade -y \
	&& apt-get install -y --no-install-recommends \
	build-essential \
	git \
	libgdal-dev

# Create and activate a Python virtual environment
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install Python requirements
COPY requirements.txt .
RUN pip install -U pip \
	&& pip install -r requirements.txt \
	&& git clone https://github.com/joefutrelle/pyifcb \
	&& pip install ./pyifcb

# ------------------------ RUN ------------------------ #

FROM python:3.9-slim-buster

# Copy production ready venv from builder
ENV VIRTUAL_ENV="/opt/venv"
COPY --from=builder $VIRTUAL_ENV $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install some GDAL requirements
RUN apt-get update && apt-get upgrade -y \
	&& apt-get install -y --no-install-recommends \
	libgdal20 \
	&& rm -rf /var/lib/apt/lists/*

# Create and switch to a non-root user
RUN useradd --create-home appuser
USER appuser

# Copy Django project
WORKDIR /home/appuser/ifcbdb
COPY ifcbdb .

EXPOSE 8000

CMD gunicorn --bind :8000 ifcbdb.wsgi:application