::g_path <- {}

/**
 * Normalize file path slashes to be unix-like forward slashes.
 * Condenses repeat slashes to a single slash and removes and trailing slashes.
 * Remove trailing slashes if not a root linux path "/".
 * Removing dot-segments . and .. and remove last segment before ..
 * Add slash between disk drive letter and the ramaining path if not specified.
 * Examples:
 *   normalize("/")                   > "/"
 *   normalize("/home/")              > "/home"
 *   normalize("C:a")                 > "C:/a"
 *   normalize("a/b/c/../d")          > "a/b/d"
 *   normalize("a/b/c/../../d")       > "a/d"
 *   normalize("a/b/c/../../../d")    > "d"
 *   normalize("a/b/c/../../../../d") > "d"
 *   normalize("/a/../../d")          > "/d"
 *   normalize("a/.b/./c")            > "a/.b/c"
 *   normalize("/a/b///c\\d")         > "/a/b/c/d"
 */
function g_path::normalize(path)
{
  local pathSegments = ::split(path, "\\/")
  local isAbsolutePath = false

  if (path.len() > 0 && (path[0] == '/' || path[0] == "\\"[0]))
  {
    isAbsolutePath = true
    pathSegments.insert(0, "/")
  }
  else if (pathSegments.len() > 0 &&
    ::regexp("^[a-zA-Z]:.*$").match(pathSegments[0]))
  {
    isAbsolutePath = true
    if (pathSegments[0].len() > 2)
    {
      pathSegments.insert(0, pathSegments[0].slice(0, 2))
      pathSegments[1] = pathSegments[1].slice(2)
    }
  }

  local numRemoved = 0
  for (local j = pathSegments.len() - 1; j >= 0; j--)
  {
    local segment = pathSegments[j]
    if (segment == ".")
      numRemoved += 1
    else if (segment == "..")
      numRemoved += 2

    if (numRemoved > 0 && (!isAbsolutePath || j > 0))
    {
      pathSegments.remove(j)
      numRemoved--
    }
  }

  local normalizedPath = ::implode(pathSegments, "/")
  if (normalizedPath.len() > 2 && normalizedPath.slice(0, 2) == "//")
    normalizedPath = normalizedPath.slice(1)
  return normalizedPath
}


/**
 * Check is path already normalized
 */
function g_path::isNormalized(path)
{
  return path == normalize(path)
}


/**
 * Get last slash seperator index in past string
 */
function g_path::getLastSeperatorIndex(path)
{
  for (local j = path.len() - 1; j >= 0; j--)
    if (path[j] == '/')
      return j
  return -1
}


/**
 * Return the parent directory path of path.
 * If parent not exists function returns null.
 * Function return correct normalized path if source path normalized.
 * Examples:
 *   parentPath("/")              > null
 *   parentPath("/a")             > "/"
 *   parentPath("/a/b")           > "/a"
 *   parentPath("a")              > null
 *   parentPath("a/b")            > "a"
 */
function g_path::parentPath(path)
{
  if (path == "/")
    return null

  local separatorIdx = getLastSeperatorIndex(path)
  if (separatorIdx > 0)
    return path.slice(0, separatorIdx)
  else if (separatorIdx == 0)
    return "/"
  else if (separatorIdx == -1)
    return null
}


/**
 * Return the parent directory path of path.
 * If parent not exists returns null.
 * Function return correct normalized path if source path normalized.
 * Examples:
 *   parentPath("/")              > "/"
 *   parentPath("/a")             > "a"
 *   parentPath("/a/b")           > "b"
 *   parentPath("a")              > "a"
 *   parentPath("a/b")            > "b"
 */
function g_path::fileName(path)
{
  if (path == "/")
    return "/"

  local separatorIdx = getLastSeperatorIndex(path)
  if (separatorIdx == -1)
    return path
  else
    return path.slice(separatorIdx + 1)
}


/**
 * Join base path and other paths.
 * Function return correct normalized path if source paths normalized.
 * Examples:
 *   join("a", "b")              > "a/b"
 *   join("/a", "b")             > "/a/b"
 *   join("/", "b")              > "/b"
 *   join("a/b", "c/d")          > "a/b/c/d"
 *   join("/", "/")              > "/"
 */
function g_path::join(basePath, other)
{
  if (basePath == "")
    return other
  else if (other == "" || other == "/")
    return basePath
  else if (basePath[basePath.len() - 1] == '/' && other[0] == '/')
    return basePath + other.slice(1)
  else if (basePath[basePath.len() - 1] == '/' || other[0] == '/')
    return basePath + other
  else
    return basePath + "/" + other
}


/**
 * Join path segments.
 * Function return correct normalized paths if source path array normalized.
 * Examples:
 *   joinArray(["a", "b", "c"])      > "a/b/c"
 *   joinArray(["/", "a", "b", "c"]) > "/a/b/c"
 *   joinArray([])                   > ""
 *   joinArray(["/"])                > "/"
 */
function g_path::joinArray(pathArray)
{
  local path = ""
  foreach (pathSegment in pathArray)
    path = join(path, pathSegment)
  return path
}


/**
 * Split path to segments.
 * Function return correct normalized path segments if source path normalized.
 * Examples:
 *   splitToArray("a/b/c")      > ["a", "b", "c"]
 *   splitToArray("/a/b/c")     > ["/", "a", "b", "c"]
 *   splitToArray("")           > []
 *   splitToArray("/")          > ["/"]
 */
function g_path::splitToArray(path)
{
  if (path == "")
    return []

  local segments = ::split(path, "/")
  if (path[0] == '/')
    segments.insert(0, "/")

  return segments
}
