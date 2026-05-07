class AddGithubToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :github_uid, :string
    add_column :projects, :github_token, :string
    add_column :projects, :github_repo_url, :string
    add_column :projects, :github_username, :string
  end
end
