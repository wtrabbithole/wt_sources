enum HINT_PIECE_TYPE
{
  TEXT,
  TAG
}


::g_hints <- {
  hintTags = ["{{", "}}"]
  timerMark = ::g_hint_tag.TIMER.typeName
  colorTags = ["<color=", "</color>"]
}

/*
  params:
  * id          //null
  * style       //""
  * time        //0 - only to show time in text
  * timeoffset  //0 - only to show time in text
*/
function g_hints::buildHintMarkup(text, params = {})
{
  local rows = ::split(text, "\n")
  local view = {
    id = ::getTblValue("id", params)
    style = ::getTblValue("style", params, "")
    isOrderPopup = ::getTblValue("isOrderPopup", params, false)
    rows = []
  }

  local colors = [] //array of opened color tags, contains color itself

  foreach (row in rows)
  {
    local slices = []
    local rawRowPieces = splitRowToPieces(row)

    foreach (rawRowPiece in rawRowPieces)
    {
      if (rawRowPiece.type == HINT_PIECE_TYPE.TEXT)
      {
        local piece = rawRowPiece.piece
        local carriage = 0
        local unclosedTags = 0

        while (true)
        {
          local openingColorTagStartIndex = piece.find(colorTags[0], carriage)
          local closingColorTagStartIndex = piece.find(colorTags[1], carriage)

          if (openingColorTagStartIndex == null && closingColorTagStartIndex == null)
            break

          //move carriage
          if (openingColorTagStartIndex == null)
            carriage = closingColorTagStartIndex + colorTags[1].len()
          else if (closingColorTagStartIndex == null)
            carriage = openingColorTagStartIndex + colorTags[0].len()
          else
            carriage = ::min(
              openingColorTagStartIndex + colorTags[0].len(),
              closingColorTagStartIndex + colorTags[1].len()
            )

          //closing tag found, pop color from stack and continue
          if ((openingColorTagStartIndex == null && closingColorTagStartIndex != null) ||
            openingColorTagStartIndex > closingColorTagStartIndex)
          {
            if (unclosedTags > 0)
              unclosedTags--
            else
            {
              local lenBefore = piece.len()
              piece = "<color=" + colors.top() + ">" + piece
              carriage += piece.len() - lenBefore
            }

            colors.pop()
          }

          //opening tag found, add color to stack, increment unclosedTags counter
          else if ((closingColorTagStartIndex == null && openingColorTagStartIndex != null) ||
            openingColorTagStartIndex < closingColorTagStartIndex)
          {
            local colorEnd = piece.find(">", openingColorTagStartIndex)
            local colorStart = openingColorTagStartIndex + colorTags[0].len()
            colors.push(piece.slice(colorStart, colorEnd))
            unclosedTags++
          }
        }

        //close all unclosed tags
        for (local i = 0; i < unclosedTags; ++i)
          piece += colorTags[1]

        if (colors.len() > 0)
          piece = ::colorize(colors.top(), piece)

        if (piece.len())
          slices.append(getTextSlice(piece))
      }
      else if (rawRowPiece.type == HINT_PIECE_TYPE.TAG)
      {
        local tagType = ::g_hint_tag.getHintTagType(rawRowPiece.piece)
        slices.extend(tagType.getViewSlices(rawRowPiece.piece, params))
      }
    }

    view.rows.append({ slices = slices })
  }

  if (colors.len())
    ::dagor.debug("unclosed <color> tag! in text: " + text)

  return ::handyman.renderCached("gui/hint", view)
}

/**
 * Split row to atomic parts to work with
 * @return array of strings with type specifieres (text or tag)
 */
function g_hints::splitRowToPieces(row)
{
  local slices = []
  while (row.len() > 0)
  {
    local tagStartIndex = row.find(hintTags[0])

    //no tags on current row
    //put entire row in one piece and exit
    if (tagStartIndex == null)
    {
      slices.append({
        type = HINT_PIECE_TYPE.TEXT,
        piece = row
      })
      break
    }

    local tagEndIndex = row.find(hintTags[1], tagStartIndex)
    //there is unclosed tag
    //flush current row content to one piece and exit
    if (tagEndIndex == null)
    {
      slices.append({
        type = HINT_PIECE_TYPE.TEXT,
        piece = row
      })
      break
    }

    //slice piece before tag
    slices.append({
      type = HINT_PIECE_TYPE.TEXT,
      piece = row.slice(0, tagStartIndex)
    })

    //slice piece that contains tag
    slices.append({
      type = HINT_PIECE_TYPE.TAG
      piece = row.slice(tagStartIndex + hintTags[0].len(), tagEndIndex)
    })

    row = row.slice(tagEndIndex + hintTags[1].len())
  }

  return slices
}

function g_hints::getTextSlice(text)
{
  return { text = text }
}
