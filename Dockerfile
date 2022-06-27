# ------------------------ BUILD ----------------------- #

FROM python:3.9-slim-bullseye AS builder

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
# setuptools<58 needed to fix gdal<3.3 issue https://github.com/pypa/setuptools/issues/2781
RUN pip install -U pip \
    && pip install 'setuptools<58.0.0' \ 
	&& pip install -r requirements.txt \
    && git clone https://github.com/joefutrelle/pyifcb \
    && pip install ./pyifcb

# ------------------------ RUN ------------------------ #

FROM python:3.9-slim-bullseye

# Install some GDAL requirements
RUN apt-get update && apt-get upgrade -y \
	&& apt-get install -y --no-install-recommends \
	libgdal28 \
	&& rm -rf /var/lib/apt/lists/*

# Copy production ready venv from builder
ENV VIRTUAL_ENV="/opt/venv"
COPY --from=builder $VIRTUAL_ENV $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Create and switch to a non-root user
RUN useradd --create-home appuser
USER appuser

# Copy Django project
WORKDIR /home/appuser/ifcbdb
COPY ifcbdb .

EXPOSE 8000

CMD gunicorn --bind :8000 ifcbdb.wsgi:application
