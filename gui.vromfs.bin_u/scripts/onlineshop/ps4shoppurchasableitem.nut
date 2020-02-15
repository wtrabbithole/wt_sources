local psnStore = require("ps4_api.store")

local IMAGE_TYPE_INDEX = 8 //360x360 good looking on 1080p and 4k

enum PURCHASE_STATUS {
  PURCHASED = "RED_BAG" // - Already purchased and cannot be purchased again
  PURCHASED_MULTI = "BLUE_BAG" // - Already purchased and can be purchased again
  NOT_PURCHASED = "NONE" // - Not yet purchased
}

local handleNewPurchase = function(itemId) {
  ::ps4_update_purchases_on_auth();
  local taskParams = { showProgressBox = true, progressBoxText = ::loc("charServer/checking") }
  ::g_tasker.addTask(::update_entitlements_limited(true), taskParams)
  ::broadcastEvent("PS4ItemUpdate", {id = itemId})
}


local Ps4ShopPurchasableItem = class
{
  defaultIconStyle = "default_chest_debug"
  imagePath = null

  id = ""
  category = ""
  releaseDate = 0
  price = 0           // Price with discount as number
  listPrice = 0       // Original price without discount as number
  priceText = ""      // Price with discount as string
  listPriceText = ""  // Original price without discount as string
  currencyCode = ""
  isPurchasable = false
  isBought = false
  name = ""
  shortName = ""
  description = ""
  isBundle = false
  isPartOfAnyBundle = false
  consumableQuantity = 0
  productId = ""

  amount = ""

  isMultiConsumable = false
  needHeader = true //used in .tpl for discount

  skuInfo = null

  constructor(blk)
  {
    id = blk.label
    name = blk.name
    category = blk.category
    description = blk?.long_desc ?? ""

    local imagesArray = (blk.images % "array")
    local imageIndex = imagesArray.findindex(@(t) t.type == IMAGE_TYPE_INDEX)
    if (imageIndex != null && imagesArray[imageIndex]?.url)
      imagePath = "{0}?P1".subst(imagesArray[imageIndex].url)

    updateSkuInfo(blk)
  }

  function updateSkuInfo(blk)
  {
    skuInfo = blk.skus.blockCount() > 0? blk.skus.getBlock(0) : ::DataBlock()

    priceText = skuInfo?.display_price ?? ""
    listPriceText = skuInfo?.display_original_price ?? priceText
    price = skuInfo?.price ?? 0
    listPrice = skuInfo?.original_price ?? price

    productId = skuInfo?.product_id
    local purchStatus = skuInfo?.annotation_name ?? PURCHASE_STATUS.NOT_PURCHASED
    isBought = purchStatus == PURCHASE_STATUS.PURCHASED
    isPurchasable = purchStatus != PURCHASE_STATUS.PURCHASED && (skuInfo?.is_purchaseable ?? false)
    isMultiConsumable = (skuInfo?.use_count ?? 0) > 0
    if (isMultiConsumable)
      defaultIconStyle = "reward_gold"
  }

  getPriceText = @() ::colorize(haveDiscount()? "goodTextColor" : "" , price == 0? ::loc("shop/free") : priceText)
  haveDiscount = @() !isBought && price != listPrice

  getDescription = @() description

  getViewData = @(params = {}) {
    isAllBought = isBought
    price = getPriceText()
    layered_image = getIcon()
    enableBackground = true
    isInactive = isInactive()
    isItemLocked = !isPurchasable
    itemHighlight = isBought
    needAllBoughtIcon = true
    needPriceFadeBG = true
    headerText = shortName
  }.__merge(params)

  isCanBuy = @() isPurchasable && !isBought
  isInactive = @() !isPurchasable || isBought

  getIcon = @(...) imagePath ? ::LayersIcon.getCustomSizeIconData(imagePath, "pw, ph")
                             : ::LayersIcon.getIconData(null, null, 1.0, defaultIconStyle)

  getSeenId = @() id.tostring()
  canBeUnseen = @() isBought
  showDetails = function() {
    local itemId = id
    psnStore.open_checkout(
      [itemId],
      function(result) {
        if (result.action == psnStore.Action.PURCHASED)
          handleNewPurchase(itemId)
      }
    )
  }

  showDescription = function() {
    local itemId = id
    psnStore.open_product(
      itemId,
      function(result) {
        if (result.action == psnStore.Action.PURCHASED)
          handleNewPurchase(itemId)
      }
    )
  }
}

return Ps4ShopPurchasableItem
