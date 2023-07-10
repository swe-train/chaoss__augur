"""Add ml tasks

Revision ID: 21
Revises: 20
Create Date: 2023-06-23 18:17:22.651191

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '21'
down_revision = '20'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.add_column('collection_status', sa.Column('ml_status', sa.String(), server_default=sa.text("'Pending'"), nullable=False), schema='augur_operations')
    op.add_column('collection_status', sa.Column('ml_data_last_collected', postgresql.TIMESTAMP(), nullable=True), schema='augur_operations')
    op.add_column('collection_status', sa.Column('ml_task_id', sa.String(), nullable=True), schema='augur_operations')
    op.add_column('collection_status', sa.Column('ml_weight', sa.BigInteger(), nullable=True), schema='augur_operations')
    #op.drop_constraint('collection_status_repo_id_fk', 'collection_status', schema='augur_operations', type_='foreignkey')
    #op.create_foreign_key('collection_status_repo_id_fk', 'collection_status', 'repo', ['repo_id'], ['repo_id'], source_schema='augur_operations', referent_schema='augur_data')
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_column('collection_status', 'ml_weight', schema='augur_operations')
    op.drop_column('collection_status', 'ml_task_id', schema='augur_operations')
    op.drop_column('collection_status', 'ml_data_last_collected', schema='augur_operations')
    op.drop_column('collection_status', 'ml_status', schema='augur_operations')
    # ### end Alembic commands ###
