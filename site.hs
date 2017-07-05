--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll
import qualified Data.Set as S
import           Data.Maybe
import           Text.Pandoc.Options

--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
  match "images/*" $ do
    route   idRoute
    compile copyFileCompiler

  match ("projects/files/*" .||. "me/files/*") $ do
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

  match "projects/*" $ do
    route $ setExtension "html"
    compile $ pandocMathCompiler
      >>= loadAndApplyTemplate "templates/layer1.html" postCtx
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
