Feature: Food Tech

  Scenario: Restaurant does not belong to user
    Given the fixtures files are loaded:
      | sylius_channels.yml |
      | restaurants.yml     |
    And the user "bob" is loaded:
      | email      | bob@coopcycle.org |
      | password   | 123456            |
    And the user "bob" is authenticated
    And the user "bob" has role "ROLE_RESTAURANT"
    And the restaurant with id "2" belongs to user "bob"
    And I add "Accept" header equal to "application/ld+json"
    And I add "Content-Type" header equal to "application/ld+json"
    When the user "bob" sends a "GET" request to "/api/restaurants/1/orders"
    Then the response status code should be 403

  Scenario: Retrieve restaurant orders
    Given the current time is "2018-08-27 12:00:00"
    And the fixtures files are loaded:
      | sylius_channels.yml |
      | products.yml        |
      | restaurants.yml     |
    And the setting "default_tax_category" has value "tva_livraison"
    And the restaurant with id "1" has products:
      | code      |
      | PIZZA     |
      | HAMBURGER |
    Given the user "sarah" is loaded:
      | email      | sarah@coopcycle.org |
      | password   | 123456              |
    And the user "sarah" has ordered something for "2018-08-27 12:30:00" at the restaurant with id "1"
    And the user "sarah" has ordered something for "2018-08-28 12:30:00" at the restaurant with id "1"
    Given the user "bob" is loaded:
      | email      | bob@coopcycle.org |
      | password   | 123456            |
    And the user "bob" has role "ROLE_RESTAURANT"
    And the restaurant with id "1" belongs to user "bob"
    And the user "bob" is authenticated
    And I add "Accept" header equal to "application/ld+json"
    And I add "Content-Type" header equal to "application/ld+json"
    When the user "bob" sends a "GET" request to "/api/restaurants/1/orders?date=2018-08-27"
    Then the response status code should be 200
    And the response should be in JSON
    And the JSON should match:
      """
      {
        "@context":"/api/contexts/Order",
        "@id":"/api/restaurants/1/orders",
        "@type":"hydra:Collection",
        "hydra:member":@array@,
        "hydra:totalItems":1,
        "hydra:view":{
          "@id":"/api/restaurants/1/orders?date=2018-08-27",
          "@type":"hydra:PartialCollectionView"
        },
        "hydra:search":{
          "@type":"hydra:IriTemplate",
          "hydra:template":"/api/restaurants/1/orders{?date}",
          "hydra:variableRepresentation":"BasicRepresentation",
          "hydra:mapping":[
            {
              "@type":"IriTemplateMapping",
              "variable":"date",
              "property":"date",
              "required":false
            }
          ]
        }
      }
      """

  Scenario: Refuse order with reason
    Given the fixtures files are loaded:
      | sylius_channels.yml |
      | products.yml        |
      | restaurants.yml     |
    And the setting "default_tax_category" has value "tva_livraison"
    # FIXME This is needed for email notifications. It should be defined once.
    And the setting "administrator_email" has value "admin@coopcycle.org"
    And the restaurant with id "1" has products:
      | code      |
      | PIZZA     |
      | HAMBURGER |
    Given the user "sarah" is loaded:
      | email      | sarah@coopcycle.org |
      | password   | 123456              |
    And the user "sarah" has ordered something for "2018-08-27 12:30:00" at the restaurant with id "1"
    Given the user "bob" is loaded:
      | email      | bob@coopcycle.org |
      | password   | 123456            |
    And the user "bob" has role "ROLE_RESTAURANT"
    And the restaurant with id "1" belongs to user "bob"
    And the user "bob" is authenticated
    And I add "Accept" header equal to "application/ld+json"
    And I add "Content-Type" header equal to "application/ld+json"
    When the user "bob" sends a "PUT" request to "/api/orders/1/refuse" with body:
      """
      {
        "reason": "Restaurant is closing"
      }
      """
    Then the response status code should be 200
    And the response should be in JSON
    And the last order from "sarah" should be in state "refused"

  Scenario: Delay order
    Given the fixtures files are loaded:
      | sylius_channels.yml |
      | products.yml        |
      | restaurants.yml     |
    And the setting "default_tax_category" has value "tva_livraison"
    # FIXME This is needed for email notifications. It should be defined once.
    And the setting "administrator_email" has value "admin@coopcycle.org"
    And the restaurant with id "1" has products:
      | code      |
      | PIZZA     |
      | HAMBURGER |
    Given the user "sarah" is loaded:
      | email      | sarah@coopcycle.org |
      | password   | 123456              |
    And the user "sarah" has ordered something for "2018-08-27 12:30:00" at the restaurant with id "1"
    Given the user "bob" is loaded:
      | email      | bob@coopcycle.org |
      | password   | 123456            |
    And the user "bob" has role "ROLE_RESTAURANT"
    And the restaurant with id "1" belongs to user "bob"
    And the user "bob" is authenticated
    And I add "Accept" header equal to "application/ld+json"
    And I add "Content-Type" header equal to "application/ld+json"
    When the user "bob" sends a "PUT" request to "/api/orders/1/delay" with body:
      """
      {
        "delay": 20
      }
      """
    Then the response status code should be 200

  Scenario: Not authorized to delay order
    Given the fixtures files are loaded:
      | sylius_channels.yml |
      | products.yml        |
      | restaurants.yml     |
    And the setting "default_tax_category" has value "tva_livraison"
    # FIXME This is needed for email notifications. It should be defined once.
    And the setting "administrator_email" has value "admin@coopcycle.org"
    And the restaurant with id "1" has products:
      | code      |
      | PIZZA     |
      | HAMBURGER |
    Given the user "sarah" is loaded:
      | email      | sarah@coopcycle.org |
      | password   | 123456              |
    And the user "sarah" has ordered something for "2018-08-27 12:30:00" at the restaurant with id "1"
    Given the user "bob" is loaded:
      | email      | bob@coopcycle.org |
      | password   | 123456            |
    And the user "bob" has role "ROLE_RESTAURANT"
    And the restaurant with id "2" belongs to user "bob"
    And the user "bob" is authenticated
    And I add "Accept" header equal to "application/ld+json"
    And I add "Content-Type" header equal to "application/ld+json"
    When the user "bob" sends a "PUT" request to "/api/orders/1/delay" with body:
      """
      {
        "delay": 20
      }
      """
    Then the response status code should be 403
    And the JSON should match:
      """
      {
        "@context":"/api/contexts/Error",
        "@type":"hydra:Error",
        "hydra:title":"An error occurred",
        "hydra:description":"Access Denied.",
        "trace":@array@
      }
      """

  Scenario: Accept order (with empty JSON payload)
    Given the fixtures files are loaded:
      | sylius_channels.yml |
      | products.yml        |
      | restaurants.yml     |
    And the setting "default_tax_category" has value "tva_livraison"
    # FIXME This is needed for email notifications. It should be defined once.
    And the setting "administrator_email" has value "admin@coopcycle.org"
    And the restaurant with id "1" has products:
      | code      |
      | PIZZA     |
      | HAMBURGER |
    Given the user "sarah" is loaded:
      | email      | sarah@coopcycle.org |
      | password   | 123456              |
    And the user "sarah" has ordered something for "2018-08-27 12:30:00" at the restaurant with id "1"
    Given the user "bob" is loaded:
      | email      | bob@coopcycle.org |
      | password   | 123456            |
    And the user "bob" has role "ROLE_RESTAURANT"
    And the restaurant with id "1" belongs to user "bob"
    And the user "bob" is authenticated
    And I add "Accept" header equal to "application/ld+json"
    And I add "Content-Type" header equal to "application/ld+json"
    When the user "bob" sends a "PUT" request to "/api/orders/1/accept"
    Then the response status code should be 200

  Scenario: Not authorized to accept order (with empty JSON payload)
    Given the fixtures files are loaded:
      | sylius_channels.yml |
      | products.yml        |
      | restaurants.yml     |
    And the setting "default_tax_category" has value "tva_livraison"
    # FIXME This is needed for email notifications. It should be defined once.
    And the setting "administrator_email" has value "admin@coopcycle.org"
    And the restaurant with id "1" has products:
      | code      |
      | PIZZA     |
      | HAMBURGER |
    Given the user "sarah" is loaded:
      | email      | sarah@coopcycle.org |
      | password   | 123456              |
    And the user "sarah" has ordered something for "2018-08-27 12:30:00" at the restaurant with id "1"
    Given the user "bob" is loaded:
      | email      | bob@coopcycle.org |
      | password   | 123456            |
    And the user "bob" has role "ROLE_RESTAURANT"
    And the restaurant with id "2" belongs to user "bob"
    And the user "bob" is authenticated
    And I add "Accept" header equal to "application/ld+json"
    And I add "Content-Type" header equal to "application/ld+json"
    When the user "bob" sends a "PUT" request to "/api/orders/1/accept"
    Then the response status code should be 403
    And the JSON should match:
      """
      {
        "@context":"/api/contexts/Error",
        "@type":"hydra:Error",
        "hydra:title":"An error occurred",
        "hydra:description":"Access Denied.",
        "trace":@array@
      }
      """

  Scenario: Disable product
    Given the fixtures files are loaded:
      | sylius_channels.yml |
      | products.yml        |
      | restaurants.yml     |
    And the restaurant with id "1" has products:
      | code      |
      | PIZZA     |
      | HAMBURGER |
    Given the user "bob" is loaded:
      | email      | bob@coopcycle.org |
      | password   | 123456            |
    And the user "bob" has role "ROLE_RESTAURANT"
    And the restaurant with id "1" belongs to user "bob"
    And the user "bob" is authenticated
    And I add "Accept" header equal to "application/ld+json"
    And I add "Content-Type" header equal to "application/ld+json"
    When the user "bob" sends a "PUT" request to "/api/products/1" with body:
      """
      {
        "enabled": false
      }
      """
    Then the response status code should be 200

  Scenario: Not authorized to disable product
    Given the fixtures files are loaded:
      | sylius_channels.yml |
      | products.yml        |
      | restaurants.yml     |
    Given the user "bob" is loaded:
      | email      | bob@coopcycle.org |
      | password   | 123456            |
    And the user "bob" has role "ROLE_RESTAURANT"
    And the restaurant with id "1" belongs to user "bob"
    And the user "bob" is authenticated
    And I add "Accept" header equal to "application/ld+json"
    And I add "Content-Type" header equal to "application/ld+json"
    When the user "bob" sends a "PUT" request to "/api/products/1" with body:
      """
      {
        "enabled": false
      }
      """
    Then the response status code should be 403

  Scenario: Close restaurant
    Given the fixtures files are loaded:
      | sylius_channels.yml |
      | products.yml        |
      | restaurants.yml     |
    And the restaurant with id "1" has products:
      | code      |
      | PIZZA     |
      | HAMBURGER |
    Given the user "bob" is loaded:
      | email      | bob@coopcycle.org |
      | password   | 123456            |
    And the user "bob" has role "ROLE_RESTAURANT"
    And the restaurant with id "1" belongs to user "bob"
    And the user "bob" is authenticated
    And I add "Accept" header equal to "application/ld+json"
    And I add "Content-Type" header equal to "application/ld+json"
    When the user "bob" sends a "PUT" request to "/api/restaurants/1/close" with body:
      """
      {}
      """
    Then the response status code should be 200
    And the restaurant with id "1" should have "1" closing rule
