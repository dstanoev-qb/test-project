# test-cookie-cutter-template-project

## Install

To install the project, you first need to have pyenv.

If you are on MacOS and you don't have it, just run:

```bash
make install-sys-mac
```
After that, you just need to run:

```bash
make install
```

and you are ready to go.

## Logging

 Switch to either debug or info log level by setting
 ```DEBUG_LOG_LEVEL=0|1``` env var in ```Edit configuration -> environment variables```

 Example:
 ```bash
 DEBUG_LOG_LEVEL=0 python main.py
 ```

## Run the functions framework

To test your function locally, you should run the functions framework like this:

``` bash
make run
```

It will restart itself automatically on code changes.

## Clean

If you need to rerun things on a clean environment, you may use the `clean` and `clean-deps` targets.

The `clean-deps` will remove the requirements.txt file and if you run `make compile-deps` after that, you will end up
with a fully new requirements.txt with the latest versions of your dependencies.

For more precise dependency update, see the [pip-tools documentation](https://github.com/jazzband/pip-tools).

## Deploy

To deploy the project you should run the following command:

``` bash
make APPLICATION_ID=qb-pipelines-dev REGION=us-central1 deploy
```

You should provide the following variables to the snippet above in order to customize it for your own deployment
environment:
`APPLICATION_ID` => The project you want to deploy in
`REGION` => The region you want to deploy in

## Ignore files for gcloud

There is a file, called `.gcloudignore`. It stays on the same level as the `main.py` file. It's syntax is similar to the
`.gitignore` syntax, but it is capable of including ignore files (`.gitignore` itself).

We are not able to use the include functionality as our `.gitignore` is one level up, so for the moment, if you add
something in the `.gitignore`, you should add it manually in the `.gcloudignore` too.


## Useful tools

The project uses the following helper libraries:
* __pyenv__ for python virtual environments management
* __pip-tools__ for dependency management
* __pre-commit__ for code style, testing, etc.

### pyenv

After proper installation, pyenv creates the virtual environment for you and activates it everytime you navigate to the
project folder. So you never would need to activate the venv manually, which is cool :)

For more information on how pyenv works, visit the [pyenv documentation](https://github.com/pyenv/pyenv).

### pip-tools

The human readable requirements are placed in `requirements/requirements.in`. Our convention is to __not__ use versions in
the `requirements.in` file unless you really need to. If you see specific version or min/max version in the *.in file,
this could mean that:
* There is a bug in the future versions of the package and we hit it
* There is specific functionality in the specified version (range) we rely on, which is not present in the future versions
or something similar to the above.

In the regular case, the packages in the *.in file are not pinned and the pinning is done by pip-tools in the *.txt
file. If you need to pin a package to a specific version, comment the reasoning, so your colleagues are aware how to
proceed with the future package updates.

For more information on how to use pip-tools for package updates etc., take a look at the [pip-tools
documentation](https://github.com/jazzband/pip-tools).

### pytest

We use pytest in conjunction with:
* __pytest-cov__ for coverage report
* __pytest-xdist__ to run the tests in parallel
* __pytest-icdiff__ for better diffs in failed tests

The tests use all available cores by default. To change the behaviour of pytest, you could:
* change the commandline options in `.pre-commit-config.yaml` or
* add more options in pyproject.toml under `[tool.pytest]`

### pre-commit

Pre-commit is a git hooks manager.

The key points by using pre-commit are:
* It runs automatically before you commit and does the following:
  * Stashes your untracked and unstaged files
  * Runs all defined hooks on the staged files
  * If a hook fails, it aborts the commit

The configuration of pre-commit is stored in `.pre-commit-config.yaml`. For more information on the config format,
follow the [pre-commit documentation](https://pre-commit.com/).

The basic pre-commit hooks we use, are:
* __flake8__ with it's defaults and a bunch of plugins. The only deviation is the max line length of 120 symbols
* __add-trailing-comma__ to automatically format our lists/dicts/sets/etc. properly
* __isort__ to automatically sort our imports properly. We use multiline output № 2 and balanced wrapping.
* __bandit__ for various security checks
* __mypy__ for static type checks
* __pytest__ for unit and integration testing
* hooks to always put a new line at the end of the files and to remove the trailing whitespace, where applicable

### pyproject.toml

We use the `pyproject.toml` file to configure our tools, instead of creating one configuration file for each of them.

If you add a tool, check if it is able to parse toml files and use pyproject.toml with precedence if possible.

# IDE Configuration

## isort

To configure your IDE to use isort, check [this documentation](https://github.com/pycqa/isort/wiki/isort-Plugins).
