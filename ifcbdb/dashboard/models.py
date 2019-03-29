from django.db import models

FILL_VALUE = -9999

class Dataset(models.Model):
    name = models.CharField(max_length=64)
    title = models.CharField(max_length=256)

class DataDirectory(models.Model):
    dataset = models.ForeignKey(Dataset, on_delete=models.CASCADE, related_name='directories')
    path = models.CharField(max_length=512) # absolute path
    kind = models.CharField(max_length=32, default='raw')
    priority = models.IntegerField(default=1) # order in which directories are searched (lower ealier)
    last_synced = models.DateTimeField('time of last db sync')
    # parameters controlling searching (simple comma separated fields because we don't have to query on these)
    whitelist = models.CharField(max_length=512, default='data') # comma separated list of directory names to search
    blacklist = models.CharField(max_length=512, default='skip,bad') # comma separated list of directory names to skip

class Bin(models.Model):
    # bin's permanent identifier (e.g., D20190102T1234_IFCB927)
    pid = models.CharField(max_length=64)
    # the parsed bin timestamp
    timestamp = models.DateTimeField('bin timestamp')
    # spatiotemporal information
    sample_time = models.DateTimeField('sample time')
    latitude = models.FloatField(default=FILL_VALUE)
    longitude = models.FloatField(default=FILL_VALUE)
    depth = models.FloatField(default=0)
    # many-to-many relationship with datasets
    datasets = models.ManyToManyField('Dataset', related_name='bins')
    # qaqc flags
    qc_bad = models.BooleanField(default=False) # is this bin invalid
    # metrics
    temperature = models.FloatField(default=FILL_VALUE)
    humidity = models.FloatField(default=FILL_VALUE)
    run_time = models.FloatField(default=FILL_VALUE)
    ml_analyzed = models.FloatField(default=FILL_VALUE)
