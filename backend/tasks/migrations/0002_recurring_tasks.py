# Generated migration for recurring tasks support

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('tasks', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='task',
            name='recurring',
            field=models.CharField(
                choices=[
                    ('NONE', 'No Recurrence'),
                    ('DAILY', 'Daily'),
                    ('WEEKLY', 'Weekly'),
                    ('MONTHLY', 'Monthly'),
                ],
                default='NONE',
                max_length=20,
            ),
        ),
        migrations.AddField(
            model_name='task',
            name='is_recurring_instance',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='task',
            name='recurring_parent',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='recurring_instances',
                to='tasks.task',
            ),
        ),
    ]
