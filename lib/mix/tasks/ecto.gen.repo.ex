defmodule Mix.Tasks.Ecto.Gen.Repo do
  use Mix.Task

  import Mix.Ecto
  import Mix.Generator

  @shortdoc "Generates a new repository"

  @moduledoc """
  Generates a new repository.

  The repository will be placed in the `lib` directory.

  ## Examples

      mix ecto.gen.repo
      mix ecto.gen.repo -r Custom.Repo

  ## Command line options

    * `-r`, `--repo` - the repo to generate (defaults to `YourApp.Repo`)

  """

  @doc false
  def run(args) do
    no_umbrella!("ecto.gen.repo")
    repo = parse_repo(args)

    config      = Mix.Project.config
    underscored = Mix.Utils.underscore(inspect(repo))

    base = Path.basename(underscored)
    file = Path.join("lib", underscored) <> ".ex"
    app  = config[:app] || :YOUR_APP_NAME
    opts = [mod: repo, app: app, base: base]

    create_directory Path.dirname(file)
    create_file file, repo_template(opts)

    case File.read "config/config.exs" do
      {:ok, contents} ->
        Mix.shell.info [:green, "* updating ", :reset, "config/config.exs"]
        File.write! "config/config.exs", contents <> config_template(opts)
      {:error, _} ->
        create_file "config/config.exs", "use Mix.Config\n" <> config_template(opts)
    end

    open?("config/config.exs")

    Mix.shell.info """
    Don't forget to add your new repo to your supervision tree
    (typically in lib/#{app}.ex):

        worker(#{inspect repo}, [])
    """
  end

  embed_template :repo, """
  defmodule <%= inspect @mod %> do
    use Ecto.Repo,
      adapter: Ecto.Adapters.Postgres,
      otp_app: <%= inspect @app %>
  end
  """

  embed_template :config, """

  config <%= inspect @app %>, <%= inspect @mod %>,
    database: "<%= @app %>_<%= @base %>",
    username: "user",
    password: "pass",
    hostname: "localhost"
  """
end
