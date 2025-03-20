# coding: utf-8

"""
    RxInferServer OpenAPI specification

    API for RxInferServer.jl - A Julia server for RxInfer probabilistic programming framework

    The version of the OpenAPI document: 1.0.0
    Generated by OpenAPI Generator (https://openapi-generator.tech)

    Do not edit the class manually.
"""  # noqa: E501


import unittest

from RxInferClientOpenAPI.models.planning_response import PlanningResponse

class TestPlanningResponse(unittest.TestCase):
    """PlanningResponse unit test stubs"""

    def setUp(self):
        pass

    def tearDown(self):
        pass

    def make_instance(self, include_optional) -> PlanningResponse:
        """Test PlanningResponse
            include_optional is a boolean, when False only required
            params are included, when True both required and
            optional params are included """
        # uncomment below to create an instance of `PlanningResponse`
        """
        model = PlanningResponse()
        if include_optional:
            return PlanningResponse(
                event_id = 56,
                results = { },
                errors = [
                    {"error":"Unauthorized","message":"The request requires authentication, generate a token using the /generate-token endpoint"}
                    ]
            )
        else:
            return PlanningResponse(
                event_id = 56,
                results = { },
                errors = [
                    {"error":"Unauthorized","message":"The request requires authentication, generate a token using the /generate-token endpoint"}
                    ],
        )
        """

    def testPlanningResponse(self):
        """Test PlanningResponse"""
        # inst_req_only = self.make_instance(include_optional=False)
        # inst_req_and_optional = self.make_instance(include_optional=True)

if __name__ == '__main__':
    unittest.main()
