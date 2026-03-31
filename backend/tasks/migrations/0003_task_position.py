# Generated migration for task position/ordering support

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('tasks', '0002_recurring_tasks'),
    ]

    operations = [
        migrations.AddField(
            model_name='task',
            name='position',
            field=models.IntegerField(default=0),
        ),
        migrations.AlterModelOptions(
            name='task',
            options={'ordering': ['position', '-created_at']},
        ),
    ]
