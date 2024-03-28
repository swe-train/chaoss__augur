#!/bin/sh
psql -U augur -h localhost -p 5432 -d padres -c "create materialized view augur_data.explorer_contributor_actions_actionrank 
as 
SELECT
	x.cntrb_id,
	x.created_at,
	x.repo_id,
	x.repo_name,
	x.LOGIN,
	x.ACTION,
	x.RANK
FROM
	(
	SELECT
		b.cntrb_id,
		b.created_at,
		b.repo_id,
		b.repo_name,
		b.LOGIN,
		b.ACTION,
		b.RANK
	FROM
		(
		SELECT A
			.ID AS cntrb_id,
			A.created_at,
			A.repo_id,
			A.ACTION,
			repo.repo_name,
			A.LOGIN,
			RANK ( ) OVER ( PARTITION BY A.ID, A.repo_id, A.ACTION ORDER BY A.created_at ) AS RANK
		FROM
			(
				SELECT-- changed to issues.cntrb_id
				issues.reporter_id AS ID,--changed cntrb_id to reporter_id for issues.
				issues.created_at,
				issues.repo_id,
				'issue_opened' :: TEXT AS ACTION,
				contributors.cntrb_login AS LOGIN
			FROM
				augur_data.issues
				LEFT JOIN augur_data.contributors ON contributors.cntrb_id = issues.reporter_id
			WHERE
				issues.pull_request IS NULL
			UNION ALL
			SELECT
				commits.cmt_ght_author_id AS ID,
				to_timestamp( ( commits.cmt_author_date ) :: TEXT, 'YYYY-MM-DD' :: TEXT ) AS created_at,
				commits.repo_id,
				'commit' :: TEXT AS ACTION,
				contributors.cntrb_login AS LOGIN
				FROM--(
				augur_data.commits
				LEFT JOIN augur_data.contributors ON ( ( ( contributors.cntrb_id ) :: TEXT = ( commits.cmt_ght_author_id ) :: TEXT ) )
				GROUP BY commits.cmt_commit_hash, commits.cmt_ght_author_id, commits.repo_id, created_at, action, contributors.cntrb_login
			UNION ALL
			SELECT
				issue_events.cntrb_id AS ID,
				issue_events.created_at,
				issues.repo_id,
				'issue_closed' :: TEXT AS ACTION,
				contributors.cntrb_login AS LOGIN
			FROM
				augur_data.issues,
				augur_data.issue_events
				LEFT JOIN augur_data.contributors ON contributors.cntrb_id = issue_events.cntrb_id
			WHERE
				issues.issue_id = issue_events.issue_id
				AND issues.pull_request IS NULL
				AND ( ( issue_events.ACTION ) :: TEXT = 'closed' :: TEXT ) UNION ALL
			SELECT
				pull_request_events.cntrb_id AS ID,
				pull_request_events.created_at,
				pull_requests.repo_id,
				( 'pull_request_' :: TEXT || ( pull_request_events.ACTION ) :: TEXT ) AS ACTION,
				contributors.cntrb_login AS LOGIN
			FROM
				augur_data.pull_requests,
				augur_data.pull_request_events
				LEFT JOIN augur_data.contributors ON contributors.cntrb_id = pull_request_events.cntrb_id
			WHERE
				pull_requests.pull_request_id = pull_request_events.pull_request_id
				AND (
					( pull_request_events.ACTION ) :: TEXT = ANY ( ARRAY [ ( 'merged' :: CHARACTER VARYING ) :: TEXT, ( 'closed' :: CHARACTER VARYING ) :: TEXT ] )
				)
			UNION ALL
			SELECT
				pull_request_reviews.cntrb_id AS ID,
				pull_request_reviews.pr_review_submitted_at AS created_at,
				pull_requests.repo_id,
				( 'pull_request_review_' :: TEXT || ( pull_request_reviews.pr_review_state ) :: TEXT ) AS ACTION,
				contributors.cntrb_login AS LOGIN
			FROM
				augur_data.pull_requests,
				augur_data.pull_request_reviews
				LEFT JOIN augur_data.contributors ON contributors.cntrb_id = pull_request_reviews.cntrb_id
			WHERE
				pull_requests.pull_request_id = pull_request_reviews.pull_request_id UNION ALL
			SELECT
				pull_requests.pr_augur_contributor_id AS ID,
				pull_requests.pr_created_at AS created_at,
				pull_requests.repo_id,
				'open_pull_request' :: TEXT AS ACTION,
				contributors.cntrb_login AS LOGIN
			FROM
				augur_data.pull_requests
				LEFT JOIN augur_data.contributors ON pull_requests.pr_augur_contributor_id = contributors.cntrb_id
			UNION ALL
			SELECT
				message.cntrb_id AS ID,
				message.msg_timestamp AS created_at,
				pull_requests.repo_id,
				'pull_request_comment' :: TEXT AS ACTION,
				contributors.cntrb_login AS LOGIN
			FROM
				augur_data.pull_requests,
				augur_data.pull_request_message_ref,
				augur_data.message
				LEFT JOIN augur_data.contributors ON contributors.cntrb_id = message.cntrb_id
			WHERE
				pull_request_message_ref.pull_request_id = pull_requests.pull_request_id
				AND pull_request_message_ref.msg_id = message.msg_id
			UNION ALL
			SELECT
				issues.reporter_id AS ID,
				message.msg_timestamp AS created_at,
				issues.repo_id,
				'issue_comment' :: TEXT AS ACTION,
				contributors.cntrb_login AS LOGIN
			FROM
				augur_data.issues,
				augur_data.issue_message_ref,
				augur_data.message
				LEFT JOIN augur_data.contributors ON contributors.cntrb_id = message.cntrb_id
			WHERE
				issue_message_ref.msg_id = message.msg_id
				AND issues.issue_id = issue_message_ref.issue_id
			) A,
			augur_data.repo
		WHERE
			A.repo_id = repo.repo_id
		GROUP BY
			A.ID,
			A.repo_id,
			A.ACTION,
			A.created_at,
			repo.repo_name,
			A.LOGIN
		ORDER BY
			A.created_at DESC
		) b
	) x
;"
