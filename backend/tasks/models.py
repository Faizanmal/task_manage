from django.db import models
from django.db.models import Max
from datetime import timedelta


class Task(models.Model):
    STATUS_CHOICES = [
        ('TO_DO', 'To-Do'),
        ('IN_PROGRESS', 'In Progress'),
        ('DONE', 'Done'),
    ]
    
    RECURRING_CHOICES = [
        ('NONE', 'No Recurrence'),
        ('DAILY', 'Daily'),
        ('WEEKLY', 'Weekly'),
        ('MONTHLY', 'Monthly'),
    ]

    id = models.AutoField(primary_key=True)
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True, default='')
    due_date = models.DateField()
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='TO_DO'
    )
    blocked_by = models.ForeignKey(
        'self',
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='blocks'
    )
    recurring = models.CharField(
        max_length=20,
        choices=RECURRING_CHOICES,
        default='NONE'
    )
    is_recurring_instance = models.BooleanField(default=False)
    recurring_parent = models.ForeignKey(
        'self',
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='recurring_instances'
    )
    position = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['position', '-created_at']

    def __str__(self):
        return self.title
    
    def generate_next_recurring_task(self):
        """Generate next recurring task if this one is marked as done"""
        if self.status != 'DONE' or self.recurring == 'NONE':
            return None
        
        # Calculate next due date based on recurrence type
        next_due_date = self.due_date
        if self.recurring == 'DAILY':
            next_due_date = self.due_date + timedelta(days=1)
        elif self.recurring == 'WEEKLY':
            next_due_date = self.due_date + timedelta(days=7)
        elif self.recurring == 'MONTHLY':
            # Add approximately 30 days for monthly (can be customized)
            next_due_date = self.due_date + timedelta(days=30)
        
        # Get the last position to ensure new task is at the end
        last_position = Task.objects.aggregate(Max('position'))['position__max'] or 0
        
        # Create new task instance
        new_task = Task.objects.create(
            title=self.title,
            description=self.description,
            due_date=next_due_date,
            status='TO_DO',
            recurring=self.recurring,
            is_recurring_instance=True,
            recurring_parent=self.recurring_parent or self,
            position=last_position + 1,
        )
        return new_task
