from .issue_tasks import *


@celery.task
def start(owner: str, repo):
    
    logger = get_task_logger(start.name)
    session = TaskSession(logger, config)

    logger.info(f"Collecting data for {owner}/{repo}")
 
    start_task_list = []
    # start_task_list.append(pull_requests.s(owner, repo))
    start_task_list.append(issues.s(owner, repo))

    start_tasks_group = group(start_task_list)


    secondary_task_list = []
    # task_list.append(pull_request_reviews.s(owner, repo))
    secondary_task_list.append(github_events.s(owner, repo))
    # task_list.append(github_messages.s(owner, repo))
    
    secondary_task_group = group(secondary_task_list)

    job = chain(
        start_tasks_group,
        secondary_task_group,
    )

    job.apply_async()

            

