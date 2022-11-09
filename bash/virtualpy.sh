# On Mac (may work on Linux too) add the below to ~/.profile which will provide functions for managing Python virtual environments
# After updating ~/.profile run "source ~/.profile" in the terminal or open a new terminal for the changes to take effect
# To change the location virtual environments are created in change the VIRTUAL_PY_ROOT export value, it defaults to a "VirtualPy" folder in your home directory
# Requires at least one version of Python 3 installed and in the path

export VIRTUAL_PY_ROOT="${HOME}/VirtualPy"

activateEnv() {
 # Takes 1 argument, the name of the virtual environment
 # Runs the activate script for that environment
 # ex. activateEnv my-virtual-py
 source "${VIRTUAL_PY_ROOT}/${1}/bin/activate"
}

makeEnv() {
 # Requires 1 argument, the name of the virtual environment to create, must be able to be used as a directory name when quoted
 # Allows a 2nd option argument for the specific version of Python that defaults to a value of "3", appends this to "python" to the command it executes
 # If you currently have a virtual python environment activated it deactivates it first
 # It will then create a python virtual environment using the name provided and option python version provided, activate it, and upgrade pip in it
 # ex. makeEnv my-virtual-py
 # ex. makeEnv my-virtual-py 3.8
 if [ -z "$1" ]
  then echo "Virtual environment name required"
 else
  if [[ $(which python) == *"${VIRTUAL_PY_ROOT}"* ]]; then deactivate; fi
  local VERSION="$2"
  local VERSION=${VERSION:="3"}
  cmd=(python$VERSION -m venv "${VIRTUAL_PY_ROOT}/${1}")
  "${cmd[@]}"
  activateEnv ${1}
  pip install --upgrade pip
 fi
}

rmEnv() {
 # Requires 1 argument, the name of the virtual environment to delete
 # If you currently have the virtual environmnet activated it will deactivate it first
 # Then it removes the virtual environment folder
 # ex. rmEnv my-virtual-py
 if [ -z "$1" ]
  then echo "Virtual environment name required"
 else
  if [[ $(which python) == *"${VIRTUAL_PY_ROOT}/${1}/"* ]]; then deactivate; fi
  rm -rf "${VIRTUAL_PY_ROOT}/${1}"
 fi
}

resetEnv() {
 # Requires 1 argument, the name of the virtual environment to reset
 # Accepts an additional optional argument, the python version which is passed as the 2nd argument to makeEnv
 # Calls rmEnv then makeEnv for the environment name provided
 # ex. resetEnv my-virtual-py
 # ex. resetEnv my-virtual-py 3.8
 if [ -z "$1" ]
  then echo "Virtual environment name required"
 else
  rmEnv $1
  makeEnv $1 $2
 fi
}

showEnvs() {
 # No arguments
 # lists all the virtual environments that exist by just running ls on the VIRTUAL_PY_ROOT
 # ex. showEnvs
 ls $VIRTUAL_PY_ROOT
}
