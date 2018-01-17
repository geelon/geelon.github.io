--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll
import qualified Data.Set as S
import           Data.Maybe
import           Text.Pandoc.Options
import qualified Text.HTML.TagSoup as T
import           Data.List.Utils
import           Control.Monad.Loops (concatM)
import           Control.Monad 

--------------------------------------------------------------------------------
{- MAIN -}
main :: IO ()
main = hakyll $ do
  match directCopy $ do
    route   idRoute
    compile copyFileCompiler

  match "css/*" $ do
    route   idRoute
    compile compressCssCompiler

  match "templates/*" $ compile templateBodyCompiler


  {- Index Files -}
  match ("writing/index.*" .||. "me/*" .||. "projects/*") $ do
    route $ setExtension "html"
    compile $ pandocMathCompiler
      >>= applyStandardTemplate

  match "projects/notes/readme.*" $ do
    route $ constRoute "projects/notes/index.html"
    compile $ pandocMathCompiler
      >>= applyStandardTemplate >>= mdToHTML


  {- Post Files -}
  match (writingPosts .||. projectPosts) $ do
    route $ setExtension "html"
    compile $ pandocMathCompiler
      >>= loadAndApplyTemplate "templates/post.html" postCtx
      >>= applyStandardTemplate

  {- Archives -}
  create ["thesis-notes.html"] $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll projectPosts
      let archiveCtx =
            listField "posts" postCtx (return posts)  `mappend`
            constField "title" "Notes: Chronological" `mappend`
            defaultContext

      makeItem ""
        >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
        >>= applyStandardTemplate

  create ["archive.html"] $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll (projectPosts .||. writingPosts)
      let archiveCtx =
            listField "posts" postCtx (return posts) `mappend`
            constField "title" "Archives"            `mappend`
            defaultContext

      makeItem ""
        >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
        >>= applyStandardTemplate



--------------------------------------------------------------------------------
{- PATTERNS -}
directCopy :: Pattern
directCopy = "index.html"              .||.
             "images/*"                .||.
             "writing/files/**"        .||.
             "projects/files/**"       .||.
             "projects/notes/files/**" .||.
             "me/files/**" 

writingPosts :: Pattern
writingPosts = "writing/*" .&&.
               complement "writing/index.*"

projectPosts :: Pattern
projectPosts = "projects/notes/**" .&&.
               complement ("projects/notes/readme.*" .||.
                           "projects/notes/files/**")

--------------------------------------------------------------------------------
{- CONTEXTS -}
postCtx :: Context String
postCtx = mconcat [ dateField "date" "%B %e, %Y"
                  , defaultContext ]

--------------------------------------------------------------------------------
{- TEMPLATES -}
applyStandardTemplate :: Item String  -> Compiler (Item String)
applyStandardTemplate = loadAndApplyTemplate "templates/standard.html" defaultContext
                        >=> relativizeUrls

--------------------------------------------------------------------------------
{- COMPILERS -}             
pandocMathCompiler =
    let mathExtensions = [Ext_tex_math_dollars, Ext_tex_math_double_backslash,
                          Ext_latex_macros]
        defaultExtensions = writerExtensions defaultHakyllWriterOptions
        newExtensions = foldr S.insert defaultExtensions mathExtensions
        writerOptions = defaultHakyllWriterOptions {
                          writerExtensions = newExtensions,
                          writerHTMLMathMethod = MathJax ""
                        }
    in pandocCompilerWith defaultHakyllReaderOptions writerOptions

mdToHTML :: Item String -> Compiler (Item String)
mdToHTML item = do
    route <- getRoute $ itemIdentifier item
    return $ case route of
        Nothing -> item
        Just r  -> fmap mdToHTMLWith item


mdToHTMLWith :: String  -- ^ HTML to relativize
             -> String  -- ^ Resulting HTML
mdToHTMLWith = withUrls md
  where
    md x
      | endswith ".md" x = ((replace ".md" ".html")) x
      | otherwise = x

--------------------------------------------------------------------------------


