<?php

namespace AppBundle\Sylius\Cart;

use AppBundle\Entity\RestaurantRepository;
use Doctrine\ORM\EntityRepository;
use Sylius\Component\Order\Context\CartContextInterface;
use Sylius\Component\Order\Context\CartNotFoundException;
use Sylius\Component\Order\Model\OrderInterface;
use Sylius\Component\Order\Repository\OrderRepositoryInterface;
use Sylius\Component\Resource\Factory\FactoryInterface;
use Symfony\Component\HttpFoundation\Session\SessionInterface;

final class RestaurantCartContext implements CartContextInterface
{
    private $session;

    private $orderRepository;

    private $orderFactory;

    private $restaurantRepository;

    private $sessionKeyName;

    /**
     * @param SessionInterface $session
     * @param OrderRepositoryInterface $orderRepository
     * @param string $sessionKeyName
     */
    public function __construct(
        $requestStack,
        SessionInterface $session,
        OrderRepositoryInterface $orderRepository,
        FactoryInterface $orderFactory,
        RestaurantRepository $restaurantRepository,
        EntityRepository $storeRepository,
        string $sessionKeyName)
    {
        $this->requestStack = $requestStack;
        $this->session = $session;
        $this->orderRepository = $orderRepository;
        $this->orderFactory = $orderFactory;
        $this->restaurantRepository = $restaurantRepository;
        $this->storeRepository = $storeRepository;
        $this->sessionKeyName = $sessionKeyName;
    }

    /**
     * {@inheritdoc}
     */
    public function getCart(): OrderInterface
    {
        $store = null;
        $restaurant = null;
        $path = $this->requestStack->getCurrentRequest()->getPathInfo();

        $storeId = [];
        $restaurantId = [];

        if (preg_match('/store\/([\d]+)/', $path, $storeId)) {
            $store = $this->storeRepository->find($storeId[1]);
        }

        if (preg_match('/restaurant\/([\d]+)/', $path, $restaurantId)) {
            $restaurant = $this->restaurantRepository->find($restaurantId[1]);
        }

        if (!$this->session->has($this->sessionKeyName)) {

            if ($store !== null) {
                return $this->orderFactory->createForStore($store);
            } else if ($restaurant !== null) {
                return $this->orderFactory->createForRestaurant($restaurant);
            } else {
                throw new CartNotFoundException('Unable to create cart');
            }
        }

        $cart = $this->orderRepository->findCartById($this->session->get($this->sessionKeyName));

        if (null === $cart) {
            $this->session->remove($this->sessionKeyName);

            throw new CartNotFoundException('Unable to find the cart in session');
        }

        // replace silently cart for store and cart for restaurant
        // TO-DO : ask nicely with a pop-up
        if ($store && is_null($cart->getStore())) {
            return $this->orderFactory->createForStore($store);
        }

        if ($restaurant && is_null($cart->getRestaurant())) {
            return $this->orderFactory->createForRestaurant($store);
        }

        return $cart;
    }
}
