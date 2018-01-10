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

--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
  match "images/*" $ do
    route   idRoute
    compile copyFileCompiler

  match ("projects/files/**" .||. "me/files/**") $ do
    route   idRoute
    compile copyFileCompiler

  match "css/*" $ do
    route   idRoute
    compile compressCssCompiler

  match "writing-index.*" $ do
    route $ customRoute $ const "writing/index.html"
    compile $ pandocMathCompiler
      >>= loadAndApplyTemplate "templates/layer1.html" postCtx
      >>= relativizeUrls
         
  match "writing/*" $ do
    route $ setExtension "html"
    compile $ pandocMathCompiler
      >>= loadAndApplyTemplate "templates/writing-body.html"    postCtx
      >>= loadAndApplyTemplate "templates/layer1.html" postCtx
      >>= relativizeUrls


  match "projects/notes/readme*" $ do
    route $ constRoute "projects/notes/index.html"
    compile $ pandocMathCompiler
      >>= loadAndApplyTemplate "templates/layer1.html" postCtx
      >>= liftURL
      >>= mdToHTML
      >>= relativizeUrls

  match ("projects/notes/**" .&&. complement "projects/notes/readme*") $ do
    route $ setExtension "html"
    compile $ pandocMathCompiler
      >>= loadAndApplyTemplate "templates/writing-body.html"    postCtx
      >>= loadAndApplyTemplate "templates/layer1.html" postCtx
      >>= liftURLlevel 2
      >>= relativizeUrls

  match ("me/*" .||. "projects/*") $ do
    route $ setExtension "html"
    compile $ pandocMathCompiler
      >>= loadAndApplyTemplate "templates/layer1.html" postCtx
      >>= relativizeUrls

  match "writing/files/*" $ do
    route   idRoute
    compile copyFileCompiler
           
  create ["archive.html"] $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll "writing/*"
      let archiveCtx =
            listField "posts" postCtx (return posts) `mappend`
            constField "title" "Archives"            `mappend`
            defaultContext

      makeItem ""
        >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
        >>= loadAndApplyTemplate "templates/layer0.html" archiveCtx
        >>= relativizeUrls
        >>= mdToHTML


  match "index.html" $ do
    route   idRoute
    compile $ copyFileCompiler

  match "templates/*" $ compile templateBodyCompiler


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx = mconcat
          [ dateField "date" "%B %e, %Y"
          , defaultContext
          ]

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


-- | Relativize URL's in HTML
mdToHTMLWith :: String  -- ^ HTML to relativize
             -> String  -- ^ Resulting HTML
mdToHTMLWith = withUrls md
  where
    md x
      | endswith ".md" x = (replace ".md" ".html") x -- <$> replace "./" "./notes/") x
      | otherwise = x


liftURL :: Item String -> Compiler (Item String)
liftURL item = do
    route <- getRoute $ itemIdentifier item
    return $ case route of
        Nothing -> item
        Just r  -> fmap (withUrls up) item
          where
            up x
              | startswith "http" x = x
              | startswith "." x = "../" ++ x
              | otherwise = x

liftURLlevel :: Int -> Item String -> Compiler (Item String)
liftURLlevel n = concatM $ replicate n liftURL
--------------------------------------------------------------------------------


