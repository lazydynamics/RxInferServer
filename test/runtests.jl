using Aqua, TestItemRunner, RxInferServer

Aqua.test_all(RxInferServer; ambiguities = false, piracies = false, deps_compat = (; check_extras = false, check_weakdeps = true))

TestItemRunner.@run_package_tests()
