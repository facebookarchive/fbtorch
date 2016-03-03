package = "fbtorch"
version = "scm-1"

source = {
   url = "git://github.com/facebook/fbtorch.git",
}

description = {
   summary = "Facebook's extensions to torch. ",
   detailed = [[
   ]],
   homepage = "https://github.com/facebook/fbtorch",
   license = "BSD"
}

dependencies = {
   "torch >= 7.0",
   "totem",
}

build = {
   type = "command",
   build_command = [[
   git submodule init
   git submodule update
cmake -E make_directory build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$(LUA_BINDIR)/.." -DCMAKE_INSTALL_PREFIX="$(PREFIX)"
]],
   install_command = "cd build && $(MAKE) install"
}
